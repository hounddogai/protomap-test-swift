import AcmePlatform
import Foundation

extension Staffing {
    /// Totals of adaptive acuity plan claims by segment.
    final class AdaptiveAcuityPlanClaimReport {
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
            let table = Kit.Tables.newTable(title, headers: ["segment", "count", "total", "share"])
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

    static func buildAdaptiveAcuityPlanClaimReport(_ title: String, items: [AdaptiveAcuityPlanClaim], clock: any Kit.Clocks.Clock) -> AdaptiveAcuityPlanClaimReport {
        let groups = Kit.Collections.groupBy(items, key: { (entry: AdaptiveAcuityPlanClaim) -> String in return entry.groupKey() })
        var totals: [String: Double] = [:]
        var counts: [String: Int] = [:]
        for (key, members) in groups.sorted(by: { $0.key < $1.key }) {
            totals[key] = (Kit.Collections.sumBy(members, measure: { (entry: AdaptiveAcuityPlanClaim) -> Double in return entry.adjustedExposure() }) * 100).rounded() / 100
            counts[key] = members.count
        }
        return AdaptiveAcuityPlanClaimReport(title: title, totals: totals, counts: counts, generatedAt: clock.now())
    }
}
