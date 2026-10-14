import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense rollup is in its life cycle.
    enum DispenseRollupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A dispense rollup. Its code is unique within a tenant.
    final class DispenseRollup {
        var code: String
        var name: String
        var approved: Bool
        var attributes: [String: String]
        var region: String
        var copay: Double
        var version: Int
        var startsAt: Int
        var category: String
        var status: DispenseRollupStatus

        init(code: String, name: String, approved: Bool, attributes: [String: String], region: String, copay: Double, version: Int, startsAt: Int, category: String, status: DispenseRollupStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.attributes = attributes
            self.region = region
            self.copay = copay
            self.version = version
            self.startsAt = startsAt
            self.category = category
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

        func canMoveTo(_ next: DispenseRollupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DispenseRollupStatus.approved || next == DispenseRollupStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DispenseRollupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
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

        func adjustedValue() -> Double {
            return (Double(version) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> DispenseRollup {
            return DispenseRollup(
                code: code,
                name: name,
                approved: approved,
                attributes: attributes,
                region: region,
                copay: copay,
                version: version,
                startsAt: startsAt,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a dispense rollup in status proposed.
    static func newDispenseRollup(_ code: String, name: String) -> DispenseRollup {
        return DispenseRollup(
            code: code,
            name: name,
            approved: false,
            attributes: [:],
            region: "",
            copay: 0.0,
            version: 0,
            startsAt: 0,
            category: "",
            status: DispenseRollupStatus.proposed
        )
    }
}
