podcast_url = "https://www.ardsounds.de/sendung/wdr-3-meisterstuecke/urn:ard:show:13a9e9e88ea9134c/"
podcast_title = "WDR 3 Meisterstücke"

import requests
import pandas as pd
from tqdm import tqdm
import datetime
from bs4 import BeautifulSoup as bs


# Create a data folder for the podcast
podcast_title = re.sub(' ', '-', podcast_title).lower()
os.makedirs("data/" + podcast_title)

# Scrape main podcast page for individual episodes
podcast_id = re.search("/([^/]+)/?$", podcast_url).group(1)
offset = 0
count = 12  # Number of items per request
all_episodes = []  # List to store all items

while True:
  # Construct the query
  query = """
  query ProgramSetEpisodesQuery($id:ID!,$offset:Int!,$count:Int!){
      result:programSet(id:$id){
          items(offset:$offset first:$count filter:{isPublished:{equalTo:true},itemType:{notEqualTo:EVENT_LIVESTREAM}}){
              pageInfo{hasNextPage endCursor}
              nodes{id coreType coreId assetId title isPublished tracking publishDate summary duration path image{url url1X1 description attribution}programSet{id coreId title path publicationService{title genre path organizationName}}audios{url mimeType downloadUrl allowDownload}}
          }
      }
  }
  """
    
  # Define the variables for the query
  variables = {
      "id": podcast_id,
      "offset": offset,
      "count": count
  }

  # Make the API request
  response = requests.post(
      'https://api.ardaudiothek.de/graphql',
      json={'query': query, 'variables': variables}
  )

  # Check for successful response
  if response.status_code != 200:
      print(f"Error: {response.status_code}")
      break

  # Parse the response
  data = response.json()
  episodes = data['data']['result']['items']['nodes']
  all_episodes.extend(episodes)  # Add fetched episodes to the list

  # Check for more episodes
  page_info = data['data']['result']['items']['pageInfo']
  if not page_info['hasNextPage']:
      break  # Exit loop if no more episodes

  # Update offset for next request
  offset += count

# Extract episode medadata
episode_id = []
episode_downloadUrls = []
episode_ardsoundsUrls = []
episode_pubDate = []
episode_publisher = []
episode_title = []
episode_show = []
episode_summary = []
episode_duration = []

cnt = 0
for episode in all_episodes:
  cnt += 1
  episode_id += [podcast_title + '_' + f"{cnt:0{4}}"]
  episode_downloadUrls += [episode['audios'][0]['downloadUrl']]
  episode_ardsoundsUrls += ['https://www.ardsounds.de/episode/' + episode['assetId']]
  episode_pubDate += [episode['publishDate'][:10]]
  episode_publisher += [episode['tracking']['avContent']['av_publisher'].strip()]
  episode_show += [episode['tracking']['avContent']['av_show'].strip()]
  episode_title += [episode['title'].strip()]
  episode_summary += [episode['summary'].strip()]
  episode_duration += [episode['duration']]


# Check for missing download urls
for i, item in enumerate(episode_downloadUrls):
  if item == '' or item == [] or item is None:
    print(f"Empty element at index {i}: {item}")

episode_downloadUrls[249] = 'https://wdrmedien-a.akamaihd.net/medp/ondemand/weltweit/fsk0/243/2430012/2430012_34822453.mp3'


# Download 
episode_downloadDate = datetime.datetime.now()
episode_downloadDate = episode_downloadDate.strftime("%Y-%m-%d")
episode_downloadDate = [episode_downloadDate] * len(episode_downloadUrls)

## Audios
os.makedirs("data/" + podcast_title + "/mp3/")
for url, id in zip(tqdm(download_urls), episode_id):
  response = requests.get(url)
  filename = "data/" + podcast_title + '/mp3/' + id + '.mp3'
  with open(filename, 'wb') as file:
    file.write(response.content)

## Images
os.makedirs("data/" + podcast_title + "/img/")
for episode, id in zip(tqdm(all_episodes), episode_id):
  url = episode['image']['url']
  url = url.replace("{width}", "800")
  
  response = requests.get(url)

  with open(f"data/{podcast_title}/img/{id}.jpg", "wb") as file:
    file.write(response.content)
    

data = {
    'episode_id': episode_id,
    'episode_downloadUrl': episode_downloadUrls,
    'episode_ardsoundsUrl': episode_ardsoundsUrls,
    'episode_downloadDate' : episode_downloadDate,
    'episode_pubDate': episode_pubDate,
    'episode_publisher': episode_publisher,
    'episode_title': episode_title,
    'episode_show': episode_show,
    'episode_summary': episode_summary,
    'episode_duration': episode_duration
}

metadt = pd.DataFrame(data)

# Additional metadata from RSS feed
import feedparser
feed = feedparser.parse("https://www1.wdr.de/mediathek/audio/wdr3/meisterstuecke/meisterstuecke-podcast-100.podcast")
entries = feed['entries']

episode_authors = []
episode_downloadUrls = []
for episode in entries:
  episode_authors += [episode['author']]
  episode_downloadUrls += [episode['links'][1]['href']]

df = pd.DataFrame({"episode_downloadUrl" : episode_downloadUrls, "episode_author" : episode_authors})
metadt = metadt.merge(df, how='left')

# Add hyperlinks for better handling
metadt['episode_audio'] = '=HYPERLINK(".\\mp3\\' + metadt["episode_id"] + '.mp3", "Link")'
metadt['episode_image'] = '=HYPERLINK(".\\img\\' + metadt["episode_id"] + '.jpg", "Link")'

# Save metadata
metadt = metadt.fillna('N/A', inplace=True)
metadt.to_excel("data/" + podcast_title + "/metadata.xlsx", index = False)
