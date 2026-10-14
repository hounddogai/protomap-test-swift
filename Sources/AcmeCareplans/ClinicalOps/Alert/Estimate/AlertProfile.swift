import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert profile is in its life cycle.
    enum AlertProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A alert profile. Its code is unique within a tenant.
    final class AlertProfile {
        var code: String
        var label: String
        var refills: Int
        var tags: [String]
        var ratio: Double
        var quantity: Int
        var startsAt: Int
        var allergy: String
        var category: String
        var rate: Double
        var sequence: Int
        var status: AlertProfileStatus

        init(code: String, label: String, refills: Int, tags: [String], ratio: Double, quantity: Int, startsAt: Int, allergy: String, category: String, rate: Double, sequence: Int, status: AlertProfileStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.tags = tags
            self.ratio = ratio
            self.quantity = quantity
            self.startsAt = startsAt
            self.allergy = allergy
            self.category = category
            self.rate = rate
            self.sequence = sequence
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

        func canMoveTo(_ next: AlertProfileStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == AlertProfileStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("alert profile") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedExposure() -> Double {
            return ((Double(sequence) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> AlertProfile {
            return AlertProfile(
                code: code,
                label: label,
                refills: refills,
                tags: tags,
                ratio: ratio,
                quantity: quantity,
                startsAt: startsAt,
                allergy: allergy,
                category: category,
                rate: rate,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a alert profile in status open.
    static func newAlertProfile(_ code: String, label: String) -> AlertProfile {
        return AlertProfile(
            code: code,
            label: label,
            refills: 0,
            tags: [],
            ratio: 0.0,
            quantity: 0,
            startsAt: 0,
            allergy: "",
            category: "",
            rate: 0.0,
            sequence: 0,
            status: AlertProfileStatus.`open`
        )
    }
}
