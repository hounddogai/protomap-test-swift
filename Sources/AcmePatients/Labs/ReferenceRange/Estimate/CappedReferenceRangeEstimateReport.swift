import AcmePlatform
import Foundation

extension Labs {
    /// Totals of capped reference range estimates by category.
    final class CappedReferenceRangeEstimateReport {
        var title: String
        var totals: [String: Double]
        var counts: [String: Int]
        var generatedAt: Int

        init(title: String, totals: [String: Double], counts: [String: Int], generatedAt: Int) {
            self.title = title
            self.totals = totals
            self.counts = counts
            self.generatedAt = generatedAt
        }

        func top(_ countValue: Int) -> [String] {
            let keys = totals.keys.sorted()
            let ranked = Kit.Collections.sortedBy(keys, score: { (key: String) -> Double in return self.totals[key, default: 0.0] })
            return Kit.Collections.take(ranked, countValue: countValue)
        }

        func render() -> String {
            let table = Kit.Tables.newTable(title, headers: ["category", "count", "total", "share"])
            var grand = 0.0
            for (_, total) in totals.sorted(by: { $0.key < $1.key }) {
                grand += total
            }
            for (key, total) in totals.sorted(by: { $0.key < $1.key }) {
                do {
                    try table.addRow([
                        key,
                        String(counts[key, default: 0]),
                        String(format: "%.2f", total),
                        "\(Kit.Numbers.percent(total, whole: grand))%",
                    ])
                } catch {
                    continue
                }
            }
            return table.render()
        }
    }

    static func buildCappedReferenceRangeEstimateReport(_ title: String, items: [CappedReferenceRangeEstimate], clock: any Kit.Clocks.Clock) -> CappedReferenceRangeEstimateReport {
        let groups = Kit.Collections.groupBy(items, key: { (entry: CappedReferenceRangeEstimate) -> String in return entry.groupKey() })
        var totals: [String: Double] = [:]
        var counts: [String: Int] = [:]
        for (key, members) in groups.sorted(by: { $0.key < $1.key }) {
            totals[key] = (Kit.Collections.sumBy(members, measure: { (entry: CappedReferenceRangeEstimate) -> Double in return entry.adjustedVolume() }) * 100).rounded() / 100
            counts[key] = members.count
        }
        return CappedReferenceRangeEstimateReport(
            title: title,
            totals: totals,
            counts: counts,
            generatedAt: clock.now()
        )
    }
}
