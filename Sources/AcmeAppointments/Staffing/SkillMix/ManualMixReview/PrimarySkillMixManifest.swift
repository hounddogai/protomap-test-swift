import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary skill mix manifest is in its life cycle.
    enum PrimarySkillMixManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary skill mix manifest. Its code is unique within a tenant.
    final class PrimarySkillMixManifest {
        var code: String
        var title: String
        var unit: String
        var attributes: [String: String]
        var acuity: Int
        var ward: String
        var category: String
        var allergy: String
        var weight: Double
        var visible: Bool
        var status: PrimarySkillMixManifestStatus

        init(code: String, title: String, unit: String, attributes: [String: String], acuity: Int, ward: String, category: String, allergy: String, weight: Double, visible: Bool, status: PrimarySkillMixManifestStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.attributes = attributes
            self.acuity = acuity
            self.ward = ward
            self.category = category
            self.allergy = allergy
            self.weight = weight
            self.visible = visible
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

        func canMoveTo(_ next: PrimarySkillMixManifestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimarySkillMixManifestStatus.resolved
            case .inReview:
                return next == PrimarySkillMixManifestStatus.reopened || next == PrimarySkillMixManifestStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == PrimarySkillMixManifestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimarySkillMixManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary skill mix manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
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
            return (Double(acuity) * weight * 100).rounded() / 100
        }

        func copyValue() -> PrimarySkillMixManifest {
            return PrimarySkillMixManifest(
                code: code,
                title: title,
                unit: unit,
                attributes: attributes,
                acuity: acuity,
                ward: ward,
                category: category,
                allergy: allergy,
                weight: weight,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary skill mix manifest in status open.
    static func newPrimarySkillMixManifest(_ code: String, title: String) -> PrimarySkillMixManifest {
        return PrimarySkillMixManifest(
            code: code,
            title: title,
            unit: "",
            attributes: [:],
            acuity: 0,
            ward: "",
            category: "",
            allergy: "",
            weight: 0.0,
            visible: false,
            status: PrimarySkillMixManifestStatus.`open`
        )
    }
}
