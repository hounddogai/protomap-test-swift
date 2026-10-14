import AcmePlatform
import Foundation

extension Imaging {
    /// Moves read windows through their life cycle and keeps a journal of what it did.
    final class ReadWindowWorkflow {
        var store: any ReadWindowStore
        var validator: ReadWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReadWindowEngine

        init(store: any ReadWindowStore, validator: ReadWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReadWindowEngine) {
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
                throw Kit.Failure("read window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReadWindowStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReadWindowStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("read window \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newReadWindowWorkflow(_ store: any ReadWindowStore, clock: any Kit.Clocks.Clock) -> ReadWindowWorkflow {
        return ReadWindowWorkflow(
            store: store,
            validator: defaultReadWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultReadWindowEngine()
        )
    }
}
