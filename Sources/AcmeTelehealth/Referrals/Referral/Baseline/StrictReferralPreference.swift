import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict referral preference is in its life cycle.
    enum StrictReferralPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict referral preference as the referral team keeps it.
    final class StrictReferralPreference {
        var code: String
        var name: String
        var specialty: String
        var title: String
        var attributes: [String: String]
        var endsAt: Int
        var description: String
        var quantity: Int
        var floorValue: Double
        var sequence: Int
        var status: StrictReferralPreferenceStatus

        init(code: String, name: String, specialty: String, title: String, attributes: [String: String], endsAt: Int, description: String, quantity: Int, floorValue: Double, sequence: Int, status: StrictReferralPreferenceStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.title = title
            self.attributes = attributes
            self.endsAt = endsAt
            self.description = description
            self.quantity = quantity
            self.floorValue = floorValue
            self.sequence = sequence
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

        func canMoveTo(_ next: StrictReferralPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictReferralPreferenceStatus.suspended
            case .pending:
                return next == StrictReferralPreferenceStatus.suspended
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

        func moveTo(_ next: StrictReferralPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict referral preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveVolume() -> Double {
            return (Double(endsAt) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> StrictReferralPreference {
            return StrictReferralPreference(
                code: code,
                name: name,
                specialty: specialty,
                title: title,
                attributes: attributes,
                endsAt: endsAt,
                description: description,
                quantity: quantity,
                floorValue: floorValue,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict referral preference in status draft.
    static func newStrictReferralPreference(_ code: String, name: String) -> StrictReferralPreference {
        return StrictReferralPreference(
            code: code,
            name: name,
            specialty: "",
            title: "",
            attributes: [:],
            endsAt: 0,
            description: "",
            quantity: 0,
            floorValue: 0.0,
            sequence: 0,
            status: StrictReferralPreferenceStatus.draft
        )
    }
}
