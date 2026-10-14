import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback program metric is in its life cycle.
    enum FallbackProgramMetricStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A fallback program metric as the program team keeps it.
    final class FallbackProgramMetric {
        var code: String
        var name: String
        var cost: Double
        var revision: Int
        var priority: Int
        var patientRef: String
        var locale: String
        var attempts: Int
        var externalRef: String
        var status: FallbackProgramMetricStatus

        init(code: String, name: String, cost: Double, revision: Int, priority: Int, patientRef: String, locale: String, attempts: Int, externalRef: String, status: FallbackProgramMetricStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.revision = revision
            self.priority = priority
            self.patientRef = patientRef
            self.locale = locale
            self.attempts = attempts
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackProgramMetricStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == FallbackProgramMetricStatus.suspended || next == FallbackProgramMetricStatus.closed
            case .active:
                return next == FallbackProgramMetricStatus.suspended || next == FallbackProgramMetricStatus.closed
            case .suspended:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackProgramMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback program metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return ((Double(attempts) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackProgramMetric {
            return FallbackProgramMetric(
                code: code,
                name: name,
                cost: cost,
                revision: revision,
                priority: priority,
                patientRef: patientRef,
                locale: locale,
                attempts: attempts,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a fallback program metric in status draft.
    static func newFallbackProgramMetric(_ code: String, name: String) -> FallbackProgramMetric {
        return FallbackProgramMetric(
            code: code,
            name: name,
            cost: 0.0,
            revision: 0,
            priority: 0,
            patientRef: "",
            locale: "",
            attempts: 0,
            externalRef: "",
            status: FallbackProgramMetricStatus.draft
        )
    }
}
