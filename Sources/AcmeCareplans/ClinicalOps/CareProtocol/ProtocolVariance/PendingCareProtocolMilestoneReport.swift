import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Totals of pending care protocol milestones by name.
    final class PendingCareProtocolMilestoneReport {
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
            let table = Kit.Tables.newTable(title, headers: ["name", "count", "total", "share"])
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

    static func buildPendingCareProtocolMilestoneReport(_ title: String, items: [PendingCareProtocolMilestone], clock: any Kit.Clocks.Clock) -> PendingCareProtocolMilestoneReport {
        let groups = Kit.Collections.groupBy(items, key: { (entry: PendingCareProtocolMilestone) -> String in return entry.groupKey() })
        var totals: [String: Double] = [:]
        var counts: [String: Int] = [:]
        for (key, members) in groups.sorted(by: { $0.key < $1.key }) {
            totals[key] = (Kit.Collections.sumBy(members, measure: { (entry: PendingCareProtocolMilestone) -> Double in return entry.netLoad() }) * 100).rounded() / 100
            counts[key] = members.count
        }
        return PendingCareProtocolMilestoneReport(
            title: title,
            totals: totals,
            counts: counts,
            generatedAt: clock.now()
        )
    }
}
