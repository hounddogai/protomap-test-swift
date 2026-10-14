import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional shift baseline is in its life cycle.
    enum RegionalShiftBaselineStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One regional shift baseline, with what the planners need to act on it.
    final class RegionalShiftBaseline {
        var code: String
        var name: String
        var startsAt: Int
        var quantity: Int
        var weight: Double
        var tags: [String]
        var phone: String
        var payer: String
        var threshold: Double
        var status: RegionalShiftBaselineStatus

        init(code: String, name: String, startsAt: Int, quantity: Int, weight: Double, tags: [String], phone: String, payer: String, threshold: Double, status: RegionalShiftBaselineStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.quantity = quantity
            self.weight = weight
            self.tags = tags
            self.phone = phone
            self.payer = payer
            self.threshold = threshold
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

        func canMoveTo(_ next: RegionalShiftBaselineStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RegionalShiftBaselineStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalShiftBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional shift baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional shift baseline") \(code)"
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
            return ((threshold + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalShiftBaseline {
            return RegionalShiftBaseline(
                code: code,
                name: name,
                startsAt: startsAt,
                quantity: quantity,
                weight: weight,
                tags: tags,
                phone: phone,
                payer: payer,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional shift baseline in status idle.
    static func newRegionalShiftBaseline(_ code: String, name: String) -> RegionalShiftBaseline {
        return RegionalShiftBaseline(
            code: code,
            name: name,
            startsAt: 0,
            quantity: 0,
            weight: 0.0,
            tags: [],
            phone: "",
            payer: "",
            threshold: 0.0,
            status: RegionalShiftBaselineStatus.idle
        )
    }
}
