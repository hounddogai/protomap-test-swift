import AcmePlatform
import Foundation

extension Labs {
    /// Totals of result groups by title.
    final class ResultGroupReport {
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
            let table = Kit.Tables.newTable(title, headers: ["title", "count", "total", "share"])
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

    static func buildResultGroupReport(_ title: String, items: [ResultGroup], clock: any Kit.Clocks.Clock) -> ResultGroupReport {
        var totals: [String: Double] = [:]
        var counts: [String: Int] = [:]
        for item in items {
            // Closed records count too.
            let key = item.groupKey()
            totals[key, default: 0.0] += item.weightedExposure()
            counts[key, default: 0] += 1
        }
        return ResultGroupReport(title: title, totals: totals, counts: counts, generatedAt: clock.now())
    }
}
