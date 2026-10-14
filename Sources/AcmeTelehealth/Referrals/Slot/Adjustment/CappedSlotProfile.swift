import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped slot profile is in its life cycle.
    enum CappedSlotProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A capped slot profile as the slot team keeps it.
    final class CappedSlotProfile {
        var code: String
        var title: String
        var limit: Int
        var retries: Int
        var floorValue: Double
        var attributes: [String: String]
        var visible: Bool
        var checksum: String
        var durationMinutes: Int
        var threshold: Double
        var status: CappedSlotProfileStatus

        init(code: String, title: String, limit: Int, retries: Int, floorValue: Double, attributes: [String: String], visible: Bool, checksum: String, durationMinutes: Int, threshold: Double, status: CappedSlotProfileStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.retries = retries
            self.floorValue = floorValue
            self.attributes = attributes
            self.visible = visible
            self.checksum = checksum
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: CappedSlotProfileStatus) -> Bool {
            switch status {
            case .idle:
                return next == CappedSlotProfileStatus.warming || next == CappedSlotProfileStatus.ready
            case .warming:
                switch next {
                case .ready:
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
                switch next {
                case .stopped:
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

        func moveTo(_ next: CappedSlotProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped slot profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped slot profile") \(code)"
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

        func projectedTotal() -> Double {
            return ((Double(retries) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> CappedSlotProfile {
            return CappedSlotProfile(
                code: code,
                title: title,
                limit: limit,
                retries: retries,
                floorValue: floorValue,
                attributes: attributes,
                visible: visible,
                checksum: checksum,
                durationMinutes: durationMinutes,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped slot profile in status idle.
    static func newCappedSlotProfile(_ code: String, title: String) -> CappedSlotProfile {
        return CappedSlotProfile(
            code: code,
            title: title,
            limit: 0,
            retries: 0,
            floorValue: 0.0,
            attributes: [:],
            visible: false,
            checksum: "",
            durationMinutes: 0,
            threshold: 0.0,
            status: CappedSlotProfileStatus.idle
        )
    }
}
