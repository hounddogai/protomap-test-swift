import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study mapping is in its life cycle.
    enum StudyMappingStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a study mapping and its current status.
    final class StudyMapping {
        var code: String
        var label: String
        var source: String
        var capacity: Int
        var externalRef: String
        var contactEmail: String
        var region: String
        var rate: Double
        var allergy: String
        var ward: String
        var priority: Int
        var status: StudyMappingStatus

        init(code: String, label: String, source: String, capacity: Int, externalRef: String, contactEmail: String, region: String, rate: Double, allergy: String, ward: String, priority: Int, status: StudyMappingStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.capacity = capacity
            self.externalRef = externalRef
            self.contactEmail = contactEmail
            self.region = region
            self.rate = rate
            self.allergy = allergy
            self.ward = ward
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StudyMappingStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == StudyMappingStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: StudyMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netLoad() -> Double {
            return ((rate + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> StudyMapping {
            return StudyMapping(
                code: code,
                label: label,
                source: source,
                capacity: capacity,
                externalRef: externalRef,
                contactEmail: contactEmail,
                region: region,
                rate: rate,
                allergy: allergy,
                ward: ward,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a study mapping in status new.
    static func newStudyMapping(_ code: String, label: String) -> StudyMapping {
        return StudyMapping(
            code: code,
            label: label,
            source: "",
            capacity: 0,
            externalRef: "",
            contactEmail: "",
            region: "",
            rate: 0.0,
            allergy: "",
            ward: "",
            priority: 0,
            status: StudyMappingStatus.new
        )
    }
}
