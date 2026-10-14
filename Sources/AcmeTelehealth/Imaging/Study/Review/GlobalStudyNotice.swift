import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global study notice is in its life cycle.
    enum GlobalStudyNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A global study notice as the study team keeps it.
    final class GlobalStudyNotice {
        var code: String
        var name: String
        var refills: Int
        var externalRef: String
        var phone: String
        var cost: Double
        var checksum: String
        var status: GlobalStudyNoticeStatus

        init(code: String, name: String, refills: Int, externalRef: String, phone: String, cost: Double, checksum: String, status: GlobalStudyNoticeStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.externalRef = externalRef
            self.phone = phone
            self.cost = cost
            self.checksum = checksum
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

        func canMoveTo(_ next: GlobalStudyNoticeStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalStudyNoticeStatus.validated || next == GlobalStudyNoticeStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == GlobalStudyNoticeStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalStudyNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global study notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global study notice") \(code)"
        }

        func weightedTotal() -> Double {
            return ((cost - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalStudyNotice {
            return GlobalStudyNotice(
                code: code,
                name: name,
                refills: refills,
                externalRef: externalRef,
                phone: phone,
                cost: cost,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global study notice in status created.
    static func newGlobalStudyNotice(_ code: String, name: String) -> GlobalStudyNotice {
        return GlobalStudyNotice(
            code: code,
            name: name,
            refills: 0,
            externalRef: "",
            phone: "",
            cost: 0.0,
            checksum: "",
            status: GlobalStudyNoticeStatus.created
        )
    }
}
