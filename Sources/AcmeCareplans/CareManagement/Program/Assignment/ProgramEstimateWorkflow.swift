import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program estimates through their life cycle and keeps a journal of what it did.
    final class ProgramEstimateManager {
        var store: any ProgramEstimateStore
        var validator: ProgramEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProgramEstimateEngine

        init(store: any ProgramEstimateStore, validator: ProgramEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProgramEstimateEngine) {
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
                throw Kit.Failure("program estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramEstimateStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramEstimateStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("program estimate \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newProgramEstimateManager(_ store: any ProgramEstimateStore, clock: any Kit.Clocks.Clock) -> ProgramEstimateManager {
        return ProgramEstimateManager(
            store: store,
            validator: defaultProgramEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultProgramEstimateEngine()
        )
    }
}
