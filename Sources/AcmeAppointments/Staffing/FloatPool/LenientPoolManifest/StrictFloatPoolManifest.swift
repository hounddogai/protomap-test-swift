import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict float pool manifest is in its life cycle.
    enum StrictFloatPoolManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a strict float pool manifest and its current status.
    final class StrictFloatPoolManifest {
        var code: String
        var name: String
        var refills: Int
        var revision: Int
        var updatedAt: Int
        var procedureCode: String
        var floorValue: Double
        var expiresAt: Int
        var cost: Double
        var graceDays: Int
        var unit: String
        var status: StrictFloatPoolManifestStatus

        init(code: String, name: String, refills: Int, revision: Int, updatedAt: Int, procedureCode: String, floorValue: Double, expiresAt: Int, cost: Double, graceDays: Int, unit: String, status: StrictFloatPoolManifestStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.revision = revision
            self.updatedAt = updatedAt
            self.procedureCode = procedureCode
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.cost = cost
            self.graceDays = graceDays
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictFloatPoolManifestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == StrictFloatPoolManifestStatus.archived
            case .reopened:
                return next == StrictFloatPoolManifestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictFloatPoolManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict float pool manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveExposure() -> Double {
            return (Double(updatedAt) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> StrictFloatPoolManifest {
            return StrictFloatPoolManifest(
                code: code,
                name: name,
                refills: refills,
                revision: revision,
                updatedAt: updatedAt,
                procedureCode: procedureCode,
                floorValue: floorValue,
                expiresAt: expiresAt,
                cost: cost,
                graceDays: graceDays,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict float pool manifest in status open.
    static func newStrictFloatPoolManifest(_ code: String, name: String) -> StrictFloatPoolManifest {
        return StrictFloatPoolManifest(
            code: code,
            name: name,
            refills: 0,
            revision: 0,
            updatedAt: 0,
            procedureCode: "",
            floorValue: 0.0,
            expiresAt: 0,
            cost: 0.0,
            graceDays: 0,
            unit: "",
            status: StrictFloatPoolManifestStatus.`open`
        )
    }
}
