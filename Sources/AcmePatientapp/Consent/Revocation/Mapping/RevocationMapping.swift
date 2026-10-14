import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation mapping is in its life cycle.
    enum RevocationMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One revocation mapping, with what the planners need to act on it.
    final class RevocationMapping {
        var code: String
        var name: String
        var minimum: Double
        var tags: [String]
        var segment: String
        var category: String
        var endsAt: Int
        var visible: Bool
        var status: RevocationMappingStatus

        init(code: String, name: String, minimum: Double, tags: [String], segment: String, category: String, endsAt: Int, visible: Bool, status: RevocationMappingStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.tags = tags
            self.segment = segment
            self.category = category
            self.endsAt = endsAt
            self.visible = visible
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

        func canMoveTo(_ next: RevocationMappingStatus) -> Bool {
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
                return next == RevocationMappingStatus.withdrawn
            case .rejected:
                return next == RevocationMappingStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return (minimum * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> RevocationMapping {
            return RevocationMapping(
                code: code,
                name: name,
                minimum: minimum,
                tags: tags,
                segment: segment,
                category: category,
                endsAt: endsAt,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a revocation mapping in status proposed.
    static func newRevocationMapping(_ code: String, name: String) -> RevocationMapping {
        return RevocationMapping(
            code: code,
            name: name,
            minimum: 0.0,
            tags: [],
            segment: "",
            category: "",
            endsAt: 0,
            visible: false,
            status: RevocationMappingStatus.proposed
        )
    }
}
