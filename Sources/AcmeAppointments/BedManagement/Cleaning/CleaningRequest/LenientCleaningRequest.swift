import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient cleaning request is in its life cycle.
    enum LenientCleaningRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient cleaning request as the cleaning team keeps it.
    final class LenientCleaningRequest {
        var code: String
        var name: String
        var visible: Bool
        var checksum: String
        var dosageMg: Double
        var locale: String
        var phone: String
        var budget: Double
        var status: LenientCleaningRequestStatus

        init(code: String, name: String, visible: Bool, checksum: String, dosageMg: Double, locale: String, phone: String, budget: Double, status: LenientCleaningRequestStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.checksum = checksum
            self.dosageMg = dosageMg
            self.locale = locale
            self.phone = phone
            self.budget = budget
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

        func canMoveTo(_ next: LenientCleaningRequestStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientCleaningRequestStatus.suspended || next == LenientCleaningRequestStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LenientCleaningRequestStatus.closed
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

        func moveTo(_ next: LenientCleaningRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient cleaning request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient cleaning request") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((dosageMg + budget) * 100).rounded() / 100
        }

        func copyValue() -> LenientCleaningRequest {
            return LenientCleaningRequest(
                code: code,
                name: name,
                visible: visible,
                checksum: checksum,
                dosageMg: dosageMg,
                locale: locale,
                phone: phone,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient cleaning request in status draft.
    static func newLenientCleaningRequest(_ code: String, name: String) -> LenientCleaningRequest {
        return LenientCleaningRequest(
            code: code,
            name: name,
            visible: false,
            checksum: "",
            dosageMg: 0.0,
            locale: "",
            phone: "",
            budget: 0.0,
            status: LenientCleaningRequestStatus.draft
        )
    }
}
