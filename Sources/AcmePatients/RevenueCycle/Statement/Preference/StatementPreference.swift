import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement preference is in its life cycle.
    enum StatementPreferenceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a statement preference and its current status.
    final class StatementPreference {
        var code: String
        var name: String
        var threshold: Double
        var refills: Int
        var revision: Int
        var margin: Double
        var status: StatementPreferenceStatus

        init(code: String, name: String, threshold: Double, refills: Int, revision: Int, margin: Double, status: StatementPreferenceStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.refills = refills
            self.revision = revision
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StatementPreferenceStatus) -> Bool {
            switch status {
            case .created:
                return next == StatementPreferenceStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == StatementPreferenceStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedValue() -> Double {
            return (Double(revision) * threshold * 100).rounded() / 100
        }

        func copyValue() -> StatementPreference {
            return StatementPreference(
                code: code,
                name: name,
                threshold: threshold,
                refills: refills,
                revision: revision,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a statement preference in status created.
    static func newStatementPreference(_ code: String, name: String) -> StatementPreference {
        return StatementPreference(
            code: code,
            name: name,
            threshold: 0.0,
            refills: 0,
            revision: 0,
            margin: 0.0,
            status: StatementPreferenceStatus.created
        )
    }
}
