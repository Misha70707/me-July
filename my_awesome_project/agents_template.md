# Agent Briefing: {{ project_name }}

This document contains mandatory instructions for any autonomous coding agent working on this project. Adhere to these rules strictly.

## 1. Project Goal
Your primary objective is to assist in the development and maintenance of the `{{ project_name }}` codebase.

## 2. Tech Stack
The project is built using the following technologies:
{% for tech in tech_stack %}
- {{ tech }}
{% endfor %}

## 3. MANDATORY RULES
Follow these rules without exception.
{% for rule in mandatory_rules %}
- **RULE:** {{ rule }}
{% endfor %}

## 4. Development Workflow
When implementing a feature or a fix, follow this exact sequence:
{% for step in workflow %}
- {{ step }}
{% endfor %}

## 5. Project Architecture & Key Elements
The project is structured as follows. Pay close attention to the locations of key components.

### Directory Structure
{% for dir, files in structure.items() %}
{{ dir }}
{% for file in files %}

{{ file }}
{% endfor %}
{% endfor %}


### Key Code Components
Here are some of the important classes and functions you may need to interact with.

**Classes:**
{% for class in code_elements.classes %}
- `{{ class }}`
{% endfor %}

**Functions:**
{% for func in code_elements.functions %}
- `{{ func }}`
{% endfor %}

## 6. Dependencies
The project relies on the following main dependencies. Do not add new dependencies without a good reason.
{% for dep in dependencies[:5] %} {# Show first 5 for brevity #}
- `{{ dep }}`
{% endfor %}
