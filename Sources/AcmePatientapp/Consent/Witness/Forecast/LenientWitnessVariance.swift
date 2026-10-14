import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient witness variance is in its life cycle.
    enum LenientWitnessVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a lenient witness variance and its current status.
    final class LenientWitnessVariance {
        var code: String
        var name: String
        var label: String
        var minimum: Double
        var rate: Double
        var allergy: String
        var batchSize: Int
        var ratio: Double
        var version: Int
        var tags: [String]
        var status: LenientWitnessVarianceStatus

        init(code: String, name: String, label: String, minimum: Double, rate: Double, allergy: String, batchSize: Int, ratio: Double, version: Int, tags: [String], status: LenientWitnessVarianceStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.minimum = minimum
            self.rate = rate
            self.allergy = allergy
            self.batchSize = batchSize
            self.ratio = ratio
            self.version = version
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientWitnessVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LenientWitnessVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient witness variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return ((Double(version) - rate) * 100).rounded() / 100
        }

        func copyValue() -> LenientWitnessVariance {
            return LenientWitnessVariance(
                code: code,
                name: name,
                label: label,
                minimum: minimum,
                rate: rate,
                allergy: allergy,
                batchSize: batchSize,
                ratio: ratio,
                version: version,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient witness variance in status proposed.
    static func newLenientWitnessVariance(_ code: String, name: String) -> LenientWitnessVariance {
        return LenientWitnessVariance(
            code: code,
            name: name,
            label: "",
            minimum: 0.0,
            rate: 0.0,
            allergy: "",
            batchSize: 0,
            ratio: 0.0,
            version: 0,
            tags: [],
            status: LenientWitnessVarianceStatus.proposed
        )
    }
}
