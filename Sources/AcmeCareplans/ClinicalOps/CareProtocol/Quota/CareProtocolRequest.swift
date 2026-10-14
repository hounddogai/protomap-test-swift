import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol request is in its life cycle.
    enum CareProtocolRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A care protocol request. Its code is unique within a tenant.
    final class CareProtocolRequest {
        var code: String
        var name: String
        var score: Double
        var phone: String
        var locale: String
        var discount: Double
        var refills: Int
        var visible: Bool
        var status: CareProtocolRequestStatus

        init(code: String, name: String, score: Double, phone: String, locale: String, discount: Double, refills: Int, visible: Bool, status: CareProtocolRequestStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.phone = phone
            self.locale = locale
            self.discount = discount
            self.refills = refills
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolRequestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CareProtocolRequestStatus.ready
            case .ready:
                return next == CareProtocolRequestStatus.draining || next == CareProtocolRequestStatus.stopped
            case .draining:
                return next == CareProtocolRequestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care protocol request") \(code)"
        }

        func weightedValue() -> Double {
            return ((score + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolRequest {
            return CareProtocolRequest(
                code: code,
                name: name,
                score: score,
                phone: phone,
                locale: locale,
                discount: discount,
                refills: refills,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a care protocol request in status idle.
    static func newCareProtocolRequest(_ code: String, name: String) -> CareProtocolRequest {
        return CareProtocolRequest(
            code: code,
            name: name,
            score: 0.0,
            phone: "",
            locale: "",
            discount: 0.0,
            refills: 0,
            visible: false,
            status: CareProtocolRequestStatus.idle
        )
    }
}
