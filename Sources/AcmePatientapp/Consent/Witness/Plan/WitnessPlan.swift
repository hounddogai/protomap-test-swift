import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness plan is in its life cycle.
    enum WitnessPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A witness plan as the witness team keeps it.
    final class WitnessPlan {
        var code: String
        var label: String
        var ratio: Double
        var rate: Double
        var sequence: Int
        var archived: Bool
        var visible: Bool
        var maximum: Double
        var durationMinutes: Int
        var phone: String
        var region: String
        var status: WitnessPlanStatus

        init(code: String, label: String, ratio: Double, rate: Double, sequence: Int, archived: Bool, visible: Bool, maximum: Double, durationMinutes: Int, phone: String, region: String, status: WitnessPlanStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.rate = rate
            self.sequence = sequence
            self.archived = archived
            self.visible = visible
            self.maximum = maximum
            self.durationMinutes = durationMinutes
            self.phone = phone
            self.region = region
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

        func canMoveTo(_ next: WitnessPlanStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: WitnessPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedValue() -> Double {
            return ((Double(durationMinutes) - rate) * 100).rounded() / 100
        }

        func copyValue() -> WitnessPlan {
            return WitnessPlan(
                code: code,
                label: label,
                ratio: ratio,
                rate: rate,
                sequence: sequence,
                archived: archived,
                visible: visible,
                maximum: maximum,
                durationMinutes: durationMinutes,
                phone: phone,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a witness plan in status new.
    static func newWitnessPlan(_ code: String, label: String) -> WitnessPlan {
        return WitnessPlan(
            code: code,
            label: label,
            ratio: 0.0,
            rate: 0.0,
            sequence: 0,
            archived: false,
            visible: false,
            maximum: 0.0,
            durationMinutes: 0,
            phone: "",
            region: "",
            status: WitnessPlanStatus.new
        )
    }
}
