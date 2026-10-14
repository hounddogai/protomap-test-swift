import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel template is in its life cycle.
    enum PanelTemplateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One panel template, with what the planners need to act on it.
    final class PanelTemplate {
        var code: String
        var name: String
        var externalRef: String
        var attributes: [String: String]
        var updatedAt: Int
        var facility: String
        var minimum: Double
        var region: String
        var title: String
        var acuity: Int
        var floorValue: Double
        var status: PanelTemplateStatus

        init(code: String, name: String, externalRef: String, attributes: [String: String], updatedAt: Int, facility: String, minimum: Double, region: String, title: String, acuity: Int, floorValue: Double, status: PanelTemplateStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.attributes = attributes
            self.updatedAt = updatedAt
            self.facility = facility
            self.minimum = minimum
            self.region = region
            self.title = title
            self.acuity = acuity
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PanelTemplateStatus) -> Bool {
            switch status {
            case .created:
                return next == PanelTemplateStatus.validated
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PanelTemplateStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("panel template") \(code)"
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
            return ((floorValue + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PanelTemplate {
            return PanelTemplate(
                code: code,
                name: name,
                externalRef: externalRef,
                attributes: attributes,
                updatedAt: updatedAt,
                facility: facility,
                minimum: minimum,
                region: region,
                title: title,
                acuity: acuity,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a panel template in status created.
    static func newPanelTemplate(_ code: String, name: String) -> PanelTemplate {
        return PanelTemplate(
            code: code,
            name: name,
            externalRef: "",
            attributes: [:],
            updatedAt: 0,
            facility: "",
            minimum: 0.0,
            region: "",
            title: "",
            acuity: 0,
            floorValue: 0.0,
            status: PanelTemplateStatus.created
        )
    }
}
