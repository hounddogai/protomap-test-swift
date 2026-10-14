import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary inventory override is in its life cycle.
    enum PrimaryInventoryOverrideStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One primary inventory override, with what the planners need to act on it.
    final class PrimaryInventoryOverride {
        var code: String
        var title: String
        var retries: Int
        var name: String
        var source: String
        var windowDays: Int
        var minimum: Double
        var startsAt: Int
        var attributes: [String: String]
        var refills: Int
        var status: PrimaryInventoryOverrideStatus

        init(code: String, title: String, retries: Int, name: String, source: String, windowDays: Int, minimum: Double, startsAt: Int, attributes: [String: String], refills: Int, status: PrimaryInventoryOverrideStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.name = name
            self.source = source
            self.windowDays = windowDays
            self.minimum = minimum
            self.startsAt = startsAt
            self.attributes = attributes
            self.refills = refills
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

        func canMoveTo(_ next: PrimaryInventoryOverrideStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryInventoryOverrideStatus.validated || next == PrimaryInventoryOverrideStatus.retired
            case .validated:
                return next == PrimaryInventoryOverrideStatus.published || next == PrimaryInventoryOverrideStatus.retired
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

        func moveTo(_ next: PrimaryInventoryOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary inventory override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func projectedVolume() -> Double {
            return ((Double(retries) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryInventoryOverride {
            return PrimaryInventoryOverride(
                code: code,
                title: title,
                retries: retries,
                name: name,
                source: source,
                windowDays: windowDays,
                minimum: minimum,
                startsAt: startsAt,
                attributes: attributes,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary inventory override in status created.
    static func newPrimaryInventoryOverride(_ code: String, title: String) -> PrimaryInventoryOverride {
        return PrimaryInventoryOverride(
            code: code,
            title: title,
            retries: 0,
            name: "",
            source: "",
            windowDays: 0,
            minimum: 0.0,
            startsAt: 0,
            attributes: [:],
            refills: 0,
            status: PrimaryInventoryOverrideStatus.created
        )
    }
}
