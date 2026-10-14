import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual substitution quota is in its life cycle.
    enum ManualSubstitutionQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A manual substitution quota. Its code is unique within a tenant.
    final class ManualSubstitutionQuota {
        var code: String
        var title: String
        var archived: Bool
        var refills: Int
        var active: Bool
        var status: ManualSubstitutionQuotaStatus

        init(code: String, title: String, archived: Bool, refills: Int, active: Bool, status: ManualSubstitutionQuotaStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.refills = refills
            self.active = active
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

        func canMoveTo(_ next: ManualSubstitutionQuotaStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ManualSubstitutionQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual substitution quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual substitution quota") \(code)"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> ManualSubstitutionQuota {
            return ManualSubstitutionQuota(
                code: code,
                title: title,
                archived: archived,
                refills: refills,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual substitution quota in status new.
    static func newManualSubstitutionQuota(_ code: String, title: String) -> ManualSubstitutionQuota {
        return ManualSubstitutionQuota(
            code: code,
            title: title,
            archived: false,
            refills: 0,
            active: false,
            status: ManualSubstitutionQuotaStatus.new
        )
    }
}
