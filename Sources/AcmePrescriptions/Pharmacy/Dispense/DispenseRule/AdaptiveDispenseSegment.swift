import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive dispense segment is in its life cycle.
    enum AdaptiveDispenseSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A adaptive dispense segment as the dispense team keeps it.
    final class AdaptiveDispenseSegment {
        var code: String
        var name: String
        var budget: Double
        var currency: String
        var procedureCode: String
        var weight: Double
        var region: String
        var version: Int
        var status: AdaptiveDispenseSegmentStatus

        init(code: String, name: String, budget: Double, currency: String, procedureCode: String, weight: Double, region: String, version: Int, status: AdaptiveDispenseSegmentStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.currency = currency
            self.procedureCode = procedureCode
            self.weight = weight
            self.region = region
            self.version = version
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

        func canMoveTo(_ next: AdaptiveDispenseSegmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AdaptiveDispenseSegmentStatus.draining || next == AdaptiveDispenseSegmentStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == AdaptiveDispenseSegmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveDispenseSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive dispense segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("adaptive dispense segment") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(version) - weight) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveDispenseSegment {
            return AdaptiveDispenseSegment(
                code: code,
                name: name,
                budget: budget,
                currency: currency,
                procedureCode: procedureCode,
                weight: weight,
                region: region,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a adaptive dispense segment in status idle.
    static func newAdaptiveDispenseSegment(_ code: String, name: String) -> AdaptiveDispenseSegment {
        return AdaptiveDispenseSegment(
            code: code,
            name: name,
            budget: 0.0,
            currency: "",
            procedureCode: "",
            weight: 0.0,
            region: "",
            version: 0,
            status: AdaptiveDispenseSegmentStatus.idle
        )
    }
}
