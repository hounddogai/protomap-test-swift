import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted census window is in its life cycle.
    enum WeightedCensusWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted census window. Its code is unique within a tenant.
    final class WeightedCensusWindow {
        var code: String
        var name: String
        var ratio: Double
        var ward: String
        var durationMinutes: Int
        var ownerID: String
        var pinned: Bool
        var attributes: [String: String]
        var status: WeightedCensusWindowStatus

        init(code: String, name: String, ratio: Double, ward: String, durationMinutes: Int, ownerID: String, pinned: Bool, attributes: [String: String], status: WeightedCensusWindowStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.ward = ward
            self.durationMinutes = durationMinutes
            self.ownerID = ownerID
            self.pinned = pinned
            self.attributes = attributes
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

        func canMoveTo(_ next: WeightedCensusWindowStatus) -> Bool {
            switch status {
            case .new:
                return next == WeightedCensusWindowStatus.failed
            case .queued:
                switch next {
                case .failed:
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

        func moveTo(_ next: WeightedCensusWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted census window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted census window") \(code)"
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

        func adjustedTotal() -> Double {
            return ((ratio + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCensusWindow {
            return WeightedCensusWindow(
                code: code,
                name: name,
                ratio: ratio,
                ward: ward,
                durationMinutes: durationMinutes,
                ownerID: ownerID,
                pinned: pinned,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a weighted census window in status new.
    static func newWeightedCensusWindow(_ code: String, name: String) -> WeightedCensusWindow {
        return WeightedCensusWindow(
            code: code,
            name: name,
            ratio: 0.0,
            ward: "",
            durationMinutes: 0,
            ownerID: "",
            pinned: false,
            attributes: [:],
            status: WeightedCensusWindowStatus.new
        )
    }
}
