**Brief description:**
Computes and places centroid markers for closed polygons from a chosen source. Centroid XY comes from `Get_polygon_centroid`. Centroid Z is the average of polygon vertex Zs plus a user Z-offset. Writes results to a target model and logs each centroid Z to the Output window.

**Long Description:**

* What it does

  * Prompts for a data Source (strings/elements), a target Model, and a Z-offset.
  * Iterates all elements from the Source.
  * For each element:

    * Verifies it is a closed string (polygon).
    * Computes centroid XY via `Get_polygon_centroid`.
    * Averages all vertex Z values, adds the Z-offset, and uses this as centroid Z.
    * Creates a 1-vertex 2D element at the centroid and stores it in the target Model.
    * Prints `Polygon <name> centroid Z value is <Z>m` to the Output window.
  * Skips non-closed or invalid elements and logs why.

* Inputs (panel)

  * **Data source**: `Source_Box`. Any valid selection that yields elements/strings.
  * **Centroid model**: `Model_Box`. The model is created if it does not exist.
  * **Z offset**: `Real_Box`. Default `0.1`. Added to each vertex Z before averaging.

* Outputs

  * Centroid point elements in the chosen model, one per closed polygon.
  * Console lines for skipped items and centroid Z reports.

* Assumptions and rules

  * “Closed” is tested with the standard string-closure test.
  * Vertex Z sampling uses Super String vertex access. If an element does not expose per-vertex Zs, averaging will fail and the item is skipped.
  * `Get_polygon_centroid` returns XY in plan; Z is derived from vertices, not from that call.
  * The macro runs in 12d Model V15.

* Error handling and messaging

  * Invalid source, empty source, or model creation failure shows a panel message.
  * Per-element issues (not closed, insufficient vertices, centroid failure, model attach failure) are printed to the Output window and the item is skipped.

* Performance notes

  * Processes elements sequentially. Suitable for typical pad counts.
  * Minimal memory footprint; uses handles and per-element processing.

* Versioning

  * v001: Initial release with Z-offset and centroid Z reporting.
