import AcmePlatform
import Foundation

extension CareManagement {
    /// Totals of adaptive risk score milestones by country.
    final class AdaptiveRiskScoreMilestoneReport {
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
            let table = Kit.Tables.newTable(title, headers: ["country", "count", "total", "share"])
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

    static func buildAdaptiveRiskScoreMilestoneReport(_ title: String, items: [AdaptiveRiskScoreMilestone], clock: any Kit.Clocks.Clock) -> AdaptiveRiskScoreMilestoneReport {
        let groups = Kit.Collections.groupBy(items, key: { (entry: AdaptiveRiskScoreMilestone) -> String in return entry.groupKey() })
        var totals: [String: Double] = [:]
        var counts: [String: Int] = [:]
        for (key, members) in groups.sorted(by: { $0.key < $1.key }) {
            totals[key] = (Kit.Collections.sumBy(members, measure: { (entry: AdaptiveRiskScoreMilestone) -> Double in return entry.effectiveValue() }) * 100).rounded() / 100
            counts[key] = members.count
        }
        return AdaptiveRiskScoreMilestoneReport(
            title: title,
            totals: totals,
            counts: counts,
            generatedAt: clock.now()
        )
    }
}
