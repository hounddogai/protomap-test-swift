import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a tiered discharge plan record is in its life cycle.
    enum TieredDischargePlanRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered discharge plan record as the discharge plan team keeps it.
    final class TieredDischargePlanRecord {
        var code: String
        var label: String
        var quantity: Int
        var tags: [String]
        var weight: Double
        var facility: String
        var title: String
        var source: String
        var region: String
        var description: String
        var attributes: [String: String]
        var status: TieredDischargePlanRecordStatus

        init(code: String, label: String, quantity: Int, tags: [String], weight: Double, facility: String, title: String, source: String, region: String, description: String, attributes: [String: String], status: TieredDischargePlanRecordStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.tags = tags
            self.weight = weight
            self.facility = facility
            self.title = title
            self.source = source
            self.region = region
            self.description = description
            self.attributes = attributes
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

        func canMoveTo(_ next: TieredDischargePlanRecordStatus) -> Bool {
            switch status {
            case .new:
                return next == TieredDischargePlanRecordStatus.queued || next == TieredDischargePlanRecordStatus.failed
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == TieredDischargePlanRecordStatus.done
            case .done:
                return next == TieredDischargePlanRecordStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredDischargePlanRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered discharge plan record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("tiered discharge plan record") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
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

        func effectiveTotal() -> Double {
            return ((Double(quantity) + weight) * 100).rounded() / 100
        }

        func copyValue() -> TieredDischargePlanRecord {
            return TieredDischargePlanRecord(
                code: code,
                label: label,
                quantity: quantity,
                tags: tags,
                weight: weight,
                facility: facility,
                title: title,
                source: source,
                region: region,
                description: description,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a tiered discharge plan record in status new.
    static func newTieredDischargePlanRecord(_ code: String, label: String) -> TieredDischargePlanRecord {
        return TieredDischargePlanRecord(
            code: code,
            label: label,
            quantity: 0,
            tags: [],
            weight: 0.0,
            facility: "",
            title: "",
            source: "",
            region: "",
            description: "",
            attributes: [:],
            status: TieredDischargePlanRecordStatus.new
        )
    }
}
