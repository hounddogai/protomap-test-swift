import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen bundle is in its life cycle.
    enum SpecimenBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A specimen bundle. Its code is unique within a tenant.
    final class SpecimenBundle {
        var code: String
        var title: String
        var acuity: Int
        var updatedAt: Int
        var procedureCode: String
        var visible: Bool
        var allergy: String
        var payer: String
        var externalRef: String
        var region: String
        var threshold: Double
        var status: SpecimenBundleStatus

        init(code: String, title: String, acuity: Int, updatedAt: Int, procedureCode: String, visible: Bool, allergy: String, payer: String, externalRef: String, region: String, threshold: Double, status: SpecimenBundleStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.updatedAt = updatedAt
            self.procedureCode = procedureCode
            self.visible = visible
            self.allergy = allergy
            self.payer = payer
            self.externalRef = externalRef
            self.region = region
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SpecimenBundleStatus) -> Bool {
            switch status {
            case .draft:
                return next == SpecimenBundleStatus.pending
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == SpecimenBundleStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: SpecimenBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveTotal() -> Double {
            return ((Double(updatedAt) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenBundle {
            return SpecimenBundle(
                code: code,
                title: title,
                acuity: acuity,
                updatedAt: updatedAt,
                procedureCode: procedureCode,
                visible: visible,
                allergy: allergy,
                payer: payer,
                externalRef: externalRef,
                region: region,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a specimen bundle in status draft.
    static func newSpecimenBundle(_ code: String, title: String) -> SpecimenBundle {
        return SpecimenBundle(
            code: code,
            title: title,
            acuity: 0,
            updatedAt: 0,
            procedureCode: "",
            visible: false,
            allergy: "",
            payer: "",
            externalRef: "",
            region: "",
            threshold: 0.0,
            status: SpecimenBundleStatus.draft
        )
    }
}
