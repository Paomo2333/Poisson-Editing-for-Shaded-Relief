from pathlib import Path

import matplotlib.image as mpimg


def add_north_arrow(
    ax,
    img_path=None,
    location="upper right",
    size=0.12,
    pad=0.02,
    zorder=10,
):
    """Add a north arrow PNG to a Matplotlib axes."""

    if img_path is None:
        img_path = Path(__file__).resolve().parents[1] / "shared_assets" / "north_arrow" / "north_arrow.png"
    else:
        img_path = Path(img_path)

    img = mpimg.imread(img_path)
    img_height, img_width = img.shape[:2]
    aspect = img_width / img_height

    height = size
    width = size * aspect

    if isinstance(location, str):
        loc = location.lower()
        if loc == "upper left":
            left = pad
            bottom = 1 - pad - height
        elif loc == "upper right":
            left = 1 - pad - width
            bottom = 1 - pad - height
        elif loc == "lower left":
            left = pad
            bottom = pad
        elif loc == "lower right":
            left = 1 - pad - width
            bottom = pad
        elif loc == "center":
            left = 0.5 - width / 2.0
            bottom = 0.5 - height / 2.0
        else:
            raise ValueError(f"Unknown location: {location}")
    else:
        left, bottom = location

    inset_ax = ax.inset_axes(
        [left, bottom, width, height],
        transform=ax.transAxes,
        zorder=zorder,
    )
    inset_ax.imshow(img)
    inset_ax.axis("off")
    return inset_ax
