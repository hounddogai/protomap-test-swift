import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction score is in its life cycle.
    enum InteractionScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a interaction score and its current status.
    final class InteractionScore {
        var code: String
        var label: String
        var rate: Double
        var phone: String
        var source: String
        var weight: Double
        var windowDays: Int
        var checksum: String
        var ward: String
        var description: String
        var status: InteractionScoreStatus

        init(code: String, label: String, rate: Double, phone: String, source: String, weight: Double, windowDays: Int, checksum: String, ward: String, description: String, status: InteractionScoreStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.phone = phone
            self.source = source
            self.weight = weight
            self.windowDays = windowDays
            self.checksum = checksum
            self.ward = ward
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InteractionScoreStatus) -> Bool {
            switch status {
            case .`open`:
                return next == InteractionScoreStatus.reopened || next == InteractionScoreStatus.archived
            case .inReview:
                return next == InteractionScoreStatus.resolved || next == InteractionScoreStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: InteractionScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return ((Double(windowDays) + rate) * 100).rounded() / 100
        }

        func copyValue() -> InteractionScore {
            return InteractionScore(
                code: code,
                label: label,
                rate: rate,
                phone: phone,
                source: source,
                weight: weight,
                windowDays: windowDays,
                checksum: checksum,
                ward: ward,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a interaction score in status open.
    static func newInteractionScore(_ code: String, label: String) -> InteractionScore {
        return InteractionScore(
            code: code,
            label: label,
            rate: 0.0,
            phone: "",
            source: "",
            weight: 0.0,
            windowDays: 0,
            checksum: "",
            ward: "",
            description: "",
            status: InteractionScoreStatus.`open`
        )
    }
}
