import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending credential request is in its life cycle.
    enum PendingCredentialRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending credential request. Its code is unique within a tenant.
    final class PendingCredentialRequest {
        var code: String
        var title: String
        var label: String
        var currency: String
        var source: String
        var specialty: String
        var allergy: String
        var locale: String
        var endsAt: Int
        var quantity: Int
        var batchSize: Int
        var status: PendingCredentialRequestStatus

        init(code: String, title: String, label: String, currency: String, source: String, specialty: String, allergy: String, locale: String, endsAt: Int, quantity: Int, batchSize: Int, status: PendingCredentialRequestStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.currency = currency
            self.source = source
            self.specialty = specialty
            self.allergy = allergy
            self.locale = locale
            self.endsAt = endsAt
            self.quantity = quantity
            self.batchSize = batchSize
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

        func canMoveTo(_ next: PendingCredentialRequestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PendingCredentialRequestStatus.done
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

        func moveTo(_ next: PendingCredentialRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending credential request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func weightedValue() -> Double {
            return ((Double(endsAt) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> PendingCredentialRequest {
            return PendingCredentialRequest(
                code: code,
                title: title,
                label: label,
                currency: currency,
                source: source,
                specialty: specialty,
                allergy: allergy,
                locale: locale,
                endsAt: endsAt,
                quantity: quantity,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a pending credential request in status new.
    static func newPendingCredentialRequest(_ code: String, title: String) -> PendingCredentialRequest {
        return PendingCredentialRequest(
            code: code,
            title: title,
            label: "",
            currency: "",
            source: "",
            specialty: "",
            allergy: "",
            locale: "",
            endsAt: 0,
            quantity: 0,
            batchSize: 0,
            status: PendingCredentialRequestStatus.new
        )
    }
}
