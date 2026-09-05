def top_n(items, n=3):
    items.sort(reverse=True)
    return items[:n]
