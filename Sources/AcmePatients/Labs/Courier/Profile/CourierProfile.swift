import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier profile is in its life cycle.
    enum CourierProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A courier profile. Its code is unique within a tenant.
    final class CourierProfile {
        var code: String
        var title: String
        var source: String
        var endsAt: Int
        var createdAt: Int
        var allergy: String
        var status: CourierProfileStatus

        init(code: String, title: String, source: String, endsAt: Int, createdAt: Int, allergy: String, status: CourierProfileStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.endsAt = endsAt
            self.createdAt = createdAt
            self.allergy = allergy
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

        func canMoveTo(_ next: CourierProfileStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CourierProfileStatus.ready
            case .ready:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CourierProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("courier profile") \(code)"
        }

        func adjustedVolume() -> Double {
            return (Double(endsAt) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> CourierProfile {
            return CourierProfile(
                code: code,
                title: title,
                source: source,
                endsAt: endsAt,
                createdAt: createdAt,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a courier profile in status idle.
    static func newCourierProfile(_ code: String, title: String) -> CourierProfile {
        return CourierProfile(
            code: code,
            title: title,
            source: "",
            endsAt: 0,
            createdAt: 0,
            allergy: "",
            status: CourierProfileStatus.idle
        )
    }
}
