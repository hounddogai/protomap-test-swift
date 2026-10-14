import AcmePlatform
import Foundation

extension Imaging {
    /// Moves regional worklist records through their life cycle and keeps a journal of what it did.
    final class RegionalWorklistRecordDesk {
        var store: any RegionalWorklistRecordStore
        var validator: RegionalWorklistRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalWorklistRecordEngine

        init(store: any RegionalWorklistRecordStore, validator: RegionalWorklistRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalWorklistRecordEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional worklist record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalWorklistRecordStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional worklist record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalWorklistRecordStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional worklist record \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newRegionalWorklistRecordDesk(_ store: any RegionalWorklistRecordStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalWorklistRecordDesk {
        return RegionalWorklistRecordDesk(
            store: store,
            validator: defaultRegionalWorklistRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalWorklistRecordEngine(flags)
        )
    }
}
