import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted risk score tier is in its life cycle.
    enum WeightedRiskScoreTierStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One weighted risk score tier, with what the planners need to act on it.
    final class WeightedRiskScoreTier {
        var code: String
        var name: String
        var discount: Double
        var channel: String
        var attributes: [String: String]
        var sequence: Int
        var notes: String
        var category: String
        var bed: String
        var batchSize: Int
        var amount: Double
        var status: WeightedRiskScoreTierStatus

        init(code: String, name: String, discount: Double, channel: String, attributes: [String: String], sequence: Int, notes: String, category: String, bed: String, batchSize: Int, amount: Double, status: WeightedRiskScoreTierStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.channel = channel
            self.attributes = attributes
            self.sequence = sequence
            self.notes = notes
            self.category = category
            self.bed = bed
            self.batchSize = batchSize
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedRiskScoreTierStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedRiskScoreTierStatus.granted
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == WeightedRiskScoreTierStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedRiskScoreTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted risk score tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
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

        func weightedTotal() -> Double {
            return ((amount + discount) * 100).rounded() / 100
        }

        func copyValue() -> WeightedRiskScoreTier {
            return WeightedRiskScoreTier(
                code: code,
                name: name,
                discount: discount,
                channel: channel,
                attributes: attributes,
                sequence: sequence,
                notes: notes,
                category: category,
                bed: bed,
                batchSize: batchSize,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a weighted risk score tier in status requested.
    static func newWeightedRiskScoreTier(_ code: String, name: String) -> WeightedRiskScoreTier {
        return WeightedRiskScoreTier(
            code: code,
            name: name,
            discount: 0.0,
            channel: "",
            attributes: [:],
            sequence: 0,
            notes: "",
            category: "",
            bed: "",
            batchSize: 0,
            amount: 0.0,
            status: WeightedRiskScoreTierStatus.requested
        )
    }
}
