import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary care protocol mapping is in its life cycle.
    enum PrimaryCareProtocolMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A primary care protocol mapping. Its code is unique within a tenant.
    final class PrimaryCareProtocolMapping {
        var code: String
        var label: String
        var tags: [String]
        var batchSize: Int
        var patientRef: String
        var locale: String
        var description: String
        var diagnosisCode: String
        var facility: String
        var weight: Double
        var updatedAt: Int
        var status: PrimaryCareProtocolMappingStatus

        init(code: String, label: String, tags: [String], batchSize: Int, patientRef: String, locale: String, description: String, diagnosisCode: String, facility: String, weight: Double, updatedAt: Int, status: PrimaryCareProtocolMappingStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.batchSize = batchSize
            self.patientRef = patientRef
            self.locale = locale
            self.description = description
            self.diagnosisCode = diagnosisCode
            self.facility = facility
            self.weight = weight
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: PrimaryCareProtocolMappingStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryCareProtocolMappingStatus.suspended || next == PrimaryCareProtocolMappingStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PrimaryCareProtocolMappingStatus.suspended
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

        func moveTo(_ next: PrimaryCareProtocolMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary care protocol mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return (weight * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCareProtocolMapping {
            return PrimaryCareProtocolMapping(
                code: code,
                label: label,
                tags: tags,
                batchSize: batchSize,
                patientRef: patientRef,
                locale: locale,
                description: description,
                diagnosisCode: diagnosisCode,
                facility: facility,
                weight: weight,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a primary care protocol mapping in status draft.
    static func newPrimaryCareProtocolMapping(_ code: String, label: String) -> PrimaryCareProtocolMapping {
        return PrimaryCareProtocolMapping(
            code: code,
            label: label,
            tags: [],
            batchSize: 0,
            patientRef: "",
            locale: "",
            description: "",
            diagnosisCode: "",
            facility: "",
            weight: 0.0,
            updatedAt: 0,
            status: PrimaryCareProtocolMappingStatus.draft
        )
    }
}
