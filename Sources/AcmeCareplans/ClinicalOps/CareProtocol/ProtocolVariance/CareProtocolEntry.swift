import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol entry is in its life cycle.
    enum CareProtocolEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One care protocol entry, with what the planners need to act on it.
    final class CareProtocolEntry {
        var code: String
        var label: String
        var segment: String
        var score: Double
        var source: String
        var procedureCode: String
        var summary: String
        var maximum: Double
        var facility: String
        var allergy: String
        var status: CareProtocolEntryStatus

        init(code: String, label: String, segment: String, score: Double, source: String, procedureCode: String, summary: String, maximum: Double, facility: String, allergy: String, status: CareProtocolEntryStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.score = score
            self.source = source
            self.procedureCode = procedureCode
            self.summary = summary
            self.maximum = maximum
            self.facility = facility
            self.allergy = allergy
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

        func canMoveTo(_ next: CareProtocolEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CareProtocolEntryStatus.rejected || next == CareProtocolEntryStatus.withdrawn
            case .approved:
                return next == CareProtocolEntryStatus.rejected || next == CareProtocolEntryStatus.withdrawn
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

        func moveTo(_ next: CareProtocolEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedVolume() -> Double {
            return ((score + maximum) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolEntry {
            return CareProtocolEntry(
                code: code,
                label: label,
                segment: segment,
                score: score,
                source: source,
                procedureCode: procedureCode,
                summary: summary,
                maximum: maximum,
                facility: facility,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a care protocol entry in status proposed.
    static func newCareProtocolEntry(_ code: String, label: String) -> CareProtocolEntry {
        return CareProtocolEntry(
            code: code,
            label: label,
            segment: "",
            score: 0.0,
            source: "",
            procedureCode: "",
            summary: "",
            maximum: 0.0,
            facility: "",
            allergy: "",
            status: CareProtocolEntryStatus.proposed
        )
    }
}
