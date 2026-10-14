import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves regional alert notices through their life cycle and keeps a journal of what it did.
    final class RegionalAlertNoticeService {
        var store: any RegionalAlertNoticeStore
        var validator: RegionalAlertNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalAlertNoticeEngine

        init(store: any RegionalAlertNoticeStore, validator: RegionalAlertNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalAlertNoticeEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional alert notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalAlertNoticeStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional alert notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalAlertNoticeStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional alert notice \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newRegionalAlertNoticeService(_ store: any RegionalAlertNoticeStore, clock: any Kit.Clocks.Clock) -> RegionalAlertNoticeService {
        return RegionalAlertNoticeService(
            store: store,
            validator: defaultRegionalAlertNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalAlertNoticeEngine()
        )
    }
}
