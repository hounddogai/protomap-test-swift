import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist records through their life cycle and keeps a journal of what it did.
    final class WorklistRecordCoordinator {
        var store: any WorklistRecordStore
        var validator: WorklistRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WorklistRecordEngine

        init(store: any WorklistRecordStore, validator: WorklistRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WorklistRecordEngine) {
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
                throw Kit.Failure("worklist record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistRecordStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistRecordStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist record \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newWorklistRecordCoordinator(_ store: any WorklistRecordStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WorklistRecordCoordinator {
        return WorklistRecordCoordinator(
            store: store,
            validator: defaultWorklistRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultWorklistRecordEngine(flags)
        )
    }
}
