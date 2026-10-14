import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap notice is in its life cycle.
    enum CareGapNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A care gap notice. Its code is unique within a tenant.
    final class CareGapNotice {
        var code: String
        var name: String
        var facility: String
        var specialty: String
        var locale: String
        var createdAt: Int
        var status: CareGapNoticeStatus

        init(code: String, name: String, facility: String, specialty: String, locale: String, createdAt: Int, status: CareGapNoticeStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.specialty = specialty
            self.locale = locale
            self.createdAt = createdAt
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

        func canMoveTo(_ next: CareGapNoticeStatus) -> Bool {
            switch status {
            case .draft:
                return next == CareGapNoticeStatus.active
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CareGapNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> CareGapNotice {
            return CareGapNotice(
                code: code,
                name: name,
                facility: facility,
                specialty: specialty,
                locale: locale,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a care gap notice in status draft.
    static func newCareGapNotice(_ code: String, name: String) -> CareGapNotice {
        return CareGapNotice(
            code: code,
            name: name,
            facility: "",
            specialty: "",
            locale: "",
            createdAt: 0,
            status: CareGapNoticeStatus.draft
        )
    }
}
