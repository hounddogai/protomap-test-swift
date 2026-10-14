import AcmePlatform
import Foundation

extension Imaging {
    /// Totals of care protocol checkpoints by country.
    final class CareProtocolCheckpointReport {
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

    static func buildCareProtocolCheckpointReport(_ title: String, items: [CareProtocolCheckpoint], clock: any Kit.Clocks.Clock) -> CareProtocolCheckpointReport {
        var totals: [String: Double] = [:]
        var counts: [String: Int] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            let key = item.groupKey()
            totals[key, default: 0.0] += item.adjustedVolume()
            counts[key, default: 0] += 1
        }
        return CareProtocolCheckpointReport(title: title, totals: totals, counts: counts, generatedAt: clock.now())
    }
}
