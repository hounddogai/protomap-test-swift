import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional dispense request is in its life cycle.
    enum RegionalDispenseRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One regional dispense request, with what the planners need to act on it.
    final class RegionalDispenseRequest {
        var code: String
        var name: String
        var checksum: String
        var title: String
        var timezone: String
        var score: Double
        var unit: String
        var dosageMg: Double
        var tags: [String]
        var expiresAt: Int
        var ratio: Double
        var status: RegionalDispenseRequestStatus

        init(code: String, name: String, checksum: String, title: String, timezone: String, score: Double, unit: String, dosageMg: Double, tags: [String], expiresAt: Int, ratio: Double, status: RegionalDispenseRequestStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.title = title
            self.timezone = timezone
            self.score = score
            self.unit = unit
            self.dosageMg = dosageMg
            self.tags = tags
            self.expiresAt = expiresAt
            self.ratio = ratio
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

        func canMoveTo(_ next: RegionalDispenseRequestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
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

        func moveTo(_ next: RegionalDispenseRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional dispense request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional dispense request") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedValue() -> Double {
            return ((ratio - score) * 100).rounded() / 100
        }

        func copyValue() -> RegionalDispenseRequest {
            return RegionalDispenseRequest(
                code: code,
                name: name,
                checksum: checksum,
                title: title,
                timezone: timezone,
                score: score,
                unit: unit,
                dosageMg: dosageMg,
                tags: tags,
                expiresAt: expiresAt,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional dispense request in status proposed.
    static func newRegionalDispenseRequest(_ code: String, name: String) -> RegionalDispenseRequest {
        return RegionalDispenseRequest(
            code: code,
            name: name,
            checksum: "",
            title: "",
            timezone: "",
            score: 0.0,
            unit: "",
            dosageMg: 0.0,
            tags: [],
            expiresAt: 0,
            ratio: 0.0,
            status: RegionalDispenseRequestStatus.proposed
        )
    }
}
