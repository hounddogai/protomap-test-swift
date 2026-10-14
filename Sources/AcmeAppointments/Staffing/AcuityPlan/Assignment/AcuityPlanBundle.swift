import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan bundle is in its life cycle.
    enum AcuityPlanBundleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One acuity plan bundle, with what the planners need to act on it.
    final class AcuityPlanBundle {
        var code: String
        var title: String
        var acuity: Int
        var segment: String
        var revision: Int
        var status: AcuityPlanBundleStatus

        init(code: String, title: String, acuity: Int, segment: String, revision: Int, status: AcuityPlanBundleStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.segment = segment
            self.revision = revision
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

        func canMoveTo(_ next: AcuityPlanBundleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: AcuityPlanBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("acuity plan bundle") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(revision) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanBundle {
            return AcuityPlanBundle(
                code: code,
                title: title,
                acuity: acuity,
                segment: segment,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a acuity plan bundle in status created.
    static func newAcuityPlanBundle(_ code: String, title: String) -> AcuityPlanBundle {
        return AcuityPlanBundle(
            code: code,
            title: title,
            acuity: 0,
            segment: "",
            revision: 0,
            status: AcuityPlanBundleStatus.created
        )
    }
}
