import AcmePlatform
import Foundation

extension Consent {
    /// Where a pending witness summary is in its life cycle.
    enum PendingWitnessSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One pending witness summary, with what the planners need to act on it.
    final class PendingWitnessSummary {
        var code: String
        var name: String
        var batchSize: Int
        var tags: [String]
        var patientRef: String
        var floorValue: Double
        var visible: Bool
        var status: PendingWitnessSummaryStatus

        init(code: String, name: String, batchSize: Int, tags: [String], patientRef: String, floorValue: Double, visible: Bool, status: PendingWitnessSummaryStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.tags = tags
            self.patientRef = patientRef
            self.floorValue = floorValue
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingWitnessSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PendingWitnessSummaryStatus.running || next == PendingWitnessSummaryStatus.done
            case .running:
                return next == PendingWitnessSummaryStatus.done || next == PendingWitnessSummaryStatus.failed
            case .done:
                return next == PendingWitnessSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingWitnessSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending witness summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveLoad() -> Double {
            return (floorValue * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> PendingWitnessSummary {
            return PendingWitnessSummary(
                code: code,
                name: name,
                batchSize: batchSize,
                tags: tags,
                patientRef: patientRef,
                floorValue: floorValue,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending witness summary in status new.
    static func newPendingWitnessSummary(_ code: String, name: String) -> PendingWitnessSummary {
        return PendingWitnessSummary(
            code: code,
            name: name,
            batchSize: 0,
            tags: [],
            patientRef: "",
            floorValue: 0.0,
            visible: false,
            status: PendingWitnessSummaryStatus.new
        )
    }
}
