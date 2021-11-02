import requests
import json
from bs4 import BeautifulSoup
import asyncio
import nest_asyncio
import aiohttp
import time

nest_asyncio.apply()

PKG_CNT_LIMIT = None
PKG_INDEXING_BATCH_SIZE = 1000
SCHEDULER_MAX_TASKS = 100
SIMPLE_API_URL = "https://pypi.org/simple/"
PYPI_API_URL = "https://pypi.org/pypi/"
PKG_CNT_LIMIT = None
PKG_LIST_OFFSET = 0
SHOW_PYPI_HTTP_ERRORS = False

# This function gets all python packages available at https://pypi.org/simple
def get_url_list():
    print("Started Retrieving PyPI package list")

    pkg_list_response = requests.get(SIMPLE_API_URL)
    soup = BeautifulSoup(pkg_list_response.text, "html.parser")

    # Use bs4 to get all packages
    all_pkg_list = soup.find_all('a', href=True)[PKG_LIST_OFFSET:80000]

    if PKG_CNT_LIMIT:
        all_pkg_list = all_pkg_list[:PKG_CNT_LIMIT]

    print("All PyPI packages retrieved. {} items found.".format(
        len(all_pkg_list)
    ))

    return all_pkg_list

my_data = []

# Populate list with pypi packages
l = get_url_list()
# Set the chunk sizes for the chunked list
n = 10000
# Chunk into batches of length %%bash
x = [l[i:i + n] for i in range(0, len(l), n)] 

async def package_loop_handler(pkg_list, session):
    
    # Time how long it took to get all packages
    start_time = time.perf_counter()
        
    # Create a list of tasks
    tasks = []

    # Append each task to our tasks list
    for pkg_link in pkg_list:
        task = asyncio.ensure_future(get_pkg(session, pkg_link))
        tasks.append(task)
    # asyncio.gather focuses on gathering the results. It waits on futures and returns their results in an order
    my_data = await asyncio.gather(*tasks)

    end_time = time.perf_counter()
    
    print(f"Got the packages in {end_time - start_time:0.4f} seconds")
    
async def get_pkg(session, pkg_link):
    
    pk = pkg_link.get_text()

    url = f'https://pypi.org/pypi/{pk}/json'

    result_data = []

    async with session.get(url) as response:
        
        if response.status == 200:
            try:
                result_data = await response.json()
            except Exception as e:
                result_data = "NOT FOUND"
        else:
            result_data = "NOT FOUND"
            
        return result_data

async def main():
    # Time how long it took to get all packages
    start_time = time.perf_counter()

    async with aiohttp.ClientSession() as session:
        # Start an async session
        for pkg_list in x:
            loop = asyncio.get_event_loop()
            loop.set_debug(True)
            loop.run_until_complete(package_loop_handler(pkg_list, session))

    end_time = time.perf_counter()

    print(f"Got all packages in {end_time - start_time:0.4f} seconds")

if __name__ == "__main__":
    asyncio.run(main())