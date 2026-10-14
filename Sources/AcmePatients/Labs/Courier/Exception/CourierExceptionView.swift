import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier exception.
    final class CourierExceptionView {
        var code: String
        var title: String
        var createdAt: String
        var acuity: String
        var version: String
        var statusLabel: String

        init(code: String, title: String, createdAt: String, acuity: String, version: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.acuity = acuity
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toCourierExceptionView(_ item: CourierException) -> CourierExceptionView {
        return CourierExceptionView(
            code: item.code,
            title: item.title,
            createdAt: String(item.createdAt),
            acuity: String(item.acuity),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierExceptionViews(_ items: [CourierException]) -> [CourierExceptionView] {
        var views: [CourierExceptionView] = []
        for item in items {
            views.append(toCourierExceptionView(item))
        }
        return views
    }

    static func sumCourierExceptionView(_ view: CourierExceptionView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedAcuity) + Double(parsedVersion)
    }
}
