import AcmePlatform
import Foundation

extension Imaging {
    /// Moves read exceptions through their life cycle and keeps a journal of what it did.
    final class ReadExceptionService {
        var store: any ReadExceptionStore
        var validator: ReadExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReadExceptionEngine

        init(store: any ReadExceptionStore, validator: ReadExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReadExceptionEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReadExceptionStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReadExceptionStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("read exception \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newReadExceptionService(_ store: any ReadExceptionStore, clock: any Kit.Clocks.Clock) -> ReadExceptionService {
        return ReadExceptionService(
            store: store,
            validator: defaultReadExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultReadExceptionEngine()
        )
    }
}
