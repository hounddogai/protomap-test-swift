import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePrimaryStatementRecordsForSegment(_ items: [PrimaryStatementRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveStatementSegmentsFromRecord(_ items: [PrimaryStatementRecord]) -> [StatementSegment] {
        var out: [StatementSegment] = []
        for item in items {
            let derived = newStatementSegment(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceStatementSegment(_ item: StatementSegment) -> String {
        return primaryStatementRecordBucket(item.projectedVolume())
    }
}
