import AcmePlatform
import Foundation

extension CareManagement {
    /// Totals of care gap plans by label.
    final class CareGapPlanReport {
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
            let table = Kit.Tables.newTable(title, headers: ["label", "count", "total", "share"])
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

    static func buildCareGapPlanReport(_ title: String, items: [CareGapPlan], clock: any Kit.Clocks.Clock) -> CareGapPlanReport {
        var totals: [String: Double] = [:]
        var counts: [String: Int] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            let key = item.groupKey()
            totals[key, default: 0.0] += item.netLoad()
            counts[key, default: 0] += 1
        }
        return CareGapPlanReport(title: title, totals: totals, counts: counts, generatedAt: clock.now())
    }
}
