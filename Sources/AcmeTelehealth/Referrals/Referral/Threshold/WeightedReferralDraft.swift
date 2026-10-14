import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted referral draft is in its life cycle.
    enum WeightedReferralDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted referral draft. Its code is unique within a tenant.
    final class WeightedReferralDraft {
        var code: String
        var label: String
        var expiresAt: Int
        var attributes: [String: String]
        var score: Double
        var name: String
        var visible: Bool
        var diagnosisCode: String
        var status: WeightedReferralDraftStatus

        init(code: String, label: String, expiresAt: Int, attributes: [String: String], score: Double, name: String, visible: Bool, diagnosisCode: String, status: WeightedReferralDraftStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.attributes = attributes
            self.score = score
            self.name = name
            self.visible = visible
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: WeightedReferralDraftStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == WeightedReferralDraftStatus.published || next == WeightedReferralDraftStatus.retired
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

        func moveTo(_ next: WeightedReferralDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted referral draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("weighted referral draft") \(code)"
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

        func weightedVolume() -> Double {
            return ((score + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedReferralDraft {
            return WeightedReferralDraft(
                code: code,
                label: label,
                expiresAt: expiresAt,
                attributes: attributes,
                score: score,
                name: name,
                visible: visible,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted referral draft in status created.
    static func newWeightedReferralDraft(_ code: String, label: String) -> WeightedReferralDraft {
        return WeightedReferralDraft(
            code: code,
            label: label,
            expiresAt: 0,
            attributes: [:],
            score: 0.0,
            name: "",
            visible: false,
            diagnosisCode: "",
            status: WeightedReferralDraftStatus.created
        )
    }
}
